## Deploy en testing

Se desplegó la solución en un ambiente de pruebas de la siguiente manera.
Para el front se utilizó [Netlify](https://www.netlify.com/), para el backend [Railway](https://railway.app/), y el smart contract se desarrolló usando el framework Remix, y se desplegó en la red [Goerli](https://goerli.net/)

Las urls en las que funcionan los servicios son las siguientes

Front: https://coopsol-trazabilidad.netlify.app/  
Back: https://trazabilidad-coopsol-backend.up.railway.app/  
Smart contract: [0x0ac5D9F21Fb7071325f184B3C48DC9907493a56b](https://goerli.etherscan.io/address/0x0ac5D9F21Fb7071325f184B3C48DC9907493a56b)

# Analisis y diseño

## Primer enfoque
Luego de las reuniones llevadas a cabo con Coopsol y la UCSE, se comenzó a trabajar en el diseño de la solución.
En todos los casos, la cuestión principal a resolver era qué datos guardar, y dónde guardarlos. Esto está relacionado directamente con la forma en la que se consultarán luego los datos.

Se incursionó en un primer enfoque mientras se esperaban algunas deficiones. 
Este primer enfoque fue basado completamente en el estandar [EPCIS](https://ref.gs1.org/standards/epcis/). Luego de leer el estandar se realizó un análisis de las etapas del proceso productivo de Coopsol, generando un [modelo de flujo de negocio](https://drive.google.com/file/d/1xxmyGFp62Uc1geJj-lgkAOxyQtZkETEh/view?usp=sharing) y una matrix de [visibilidad de datos](https://docs.google.com/spreadsheets/d/1HGjPNfpIugHHjFjGOy1Tj8f63SE1-RSTDY_xllTct_4/edit?usp=sharing). Ambos documentos son necesarios para comprender que eventos contiene el proceso, de que tipo son y que datos existen sobre los mismos.
Luego de este analisis inicial, se realizó una implementación en Node con Typescript, de un backend sobre el cual poder implementar
un algoritmo de traza, que permita recolectar todos los eventos que existen en la historia de un producto.
El siguiente paso dentro de la construcción de dicho backend, fue generar un gran número de eventos de prueba, con el fin de contar
con datos para poder probar el algoritmo de traza. Se utilizó una base de datos MongoDB para guardar estos eventos, y se realizaron pruebas sobre un conjunto de 10M de eventos. Las búsquedas de traza de un producto se ejecutaban alrededor en alrededor de 20 milisegundos. 
Estos resultados se deben a la creación de indices sobre ciertos campos de los eventos, que permitian acelerar la búsqueda.
En este primer enfoque no se llegó a implementar el almacenamiento en blockchain, aunque una de las opciones consideradas era 
calcular un hash de los eventos y almacenarlos en un smart contract. Nunca se contempló el almacenamiento directo de los eventos
sobre el smart contract, debido al volumen de datos que implicaría, aunque puede ser de interés explorar ese camino.
Esta prueba nos permitió tener una mayor comprensión del proceso de Coopsol, además de conocer el estandar EPCIS, que es uno de los más utilizados para trazabilidad a nivel mundial.
El foco de esta prueba estuvo centrado en los eventos. Puede verse el código del mismo en el siguiente [repositorio](https://github.com/jonduttweiler/trazabilidad).

## Segundo enfoque
Una vez que se reanudaron las reuniones, se determinó que el primer enfoque propuesto, excedía el alcance del proyecto actual, ya que
para su implementación era necesario realizar algunas modificaciones en el sistema actual, para cumplir con el estandar EPCIS.

Se optó entonces por trabajar con un enfoque más cercano al funcionamiento actual del sistema. En éste las trazas que contienen la historia de un producto, se generan desde el sistema de trazabilidad actual y se envian a un backend, el cual tiene como responsabilidad asegurar la inmutabilidad de las mismas. Esta traza contiene toda la información de los pasos del proceso productivo, junto con los apiarios de origen de la miel.
Una vez que el backend recibe una traza calcula un hash de la misma, y almacena éste en el smart contract de trazabilidad.
El diseño del smart contract asegura que solamente pueda escribirse una vez el hash correspondiente a una traza, lo que garantiza que no puedan realizarse modificaciones posteriores.


## Diseño del segundo enfoque
En base a lo analizado en el segundo enfoque, se decidió estructurar la solución de la siguiente manera:

Backend trazabilidad: Es un backend que tiene la capacidad de recibir trazas a través de una API REST, calcular el hash de las mismas y almacenar el resultado en el smart contract de trazabilidad. Para esto es necesario que tenga una forma de comunicarse con la blockchain.

Front trazabilidad: Front que permite la consulta y validación de trazas buscandolas por el id de la mismas. Muestra al usuario la información acerca de un producto, y realiza una validación de la integridad de los mismos, consultado el hash previamente guardado en el smart contract.

Smart Contract Trazabilidad: Permite el almacenamiento de hashes, solo desde la cuenta con la que se hace el deploy. El resto de las cuentas pueden consultar los hashes pero no modificarlos. Una vez escrito un hash para un id, este no puede volver a escribirse.

### Implementación del diseño 
Se decidió implementar el backend en node, utilizando el framework express para 
la creación del API Rest. Para la comunicación con el smart contract, se utiliza la libreria [@truffle/hdwallet-provider](https://www.npmjs.com/package/@truffle/hdwallet-provider) y se configura con los datos de la cuenta con las que se hizo el deploy del smart contract.
Para el calculo del hash se utilizo la librería [object-hash](https://www.npmjs.com/package/object-hash), ya que nos resuelve algunas cuestiones como el orden de las claves en un objeto. El algoritmo elegido para la generación del hash fue SHA256, codificado en hexadecimal. Un hash con estas caracteristicas tiene una longitud de 64 caracteres.

Por el lado del front, se eligió React utilizando la misma librería para el calculo de hashes. El front por otra parte realiza consultas al smart contract a través de la libreria web3.

Los repositorios correspondientes a estos proyectos son los siguientes:  
* Front (https://github.com/ACDI-Argentina/trazabilidad-coopsol-frontend)
* Backend (https://github.com/ACDI-Argentina/trazabilidad-coopsol-backend)


## Interacción entre los componentes

El siguiente diagrama describe las interacciones que se dan entre los componentes de la solución
![alt text](./flow2.svg)


## Comprobación de hash
El proceso de comprobación de hash que es ejecutado en el browser del usuario es el siguiente:
1. Se utiliza el id de la traza, para consultar en el smart contract el hash de la misma.
2. Se consulta al sistema de trazabilidad, pidiendo la traza por su id. Una vez recibida la traza se utiliza para mostrar al usuario la información del producto.
3. Se calcula en el browser el hash de la traza recibida en el punto 2.
4. Se compara el hash del punto 1 con el del punto 4. Si la traza no sufrió modificaciones los hashes deben coincidir.

