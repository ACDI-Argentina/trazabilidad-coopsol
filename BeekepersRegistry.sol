// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract BeekepersRegistry {

    struct Beekeper {
        string id; // Id en el sistema de trazabilidad actual
        string fullname;
        uint256 activityStartDate;
        string location; /* Ej: Sauzalito, CH, ARG  */
        string infoCid; /* Email, Cuit, comercio justo, productor orgánico, foto, fotos, archivos. */
        uint keyIndex; //Esto nos indica donde tenemos la referencia desde el array
    }
        

    /* Pattern iterable mappings https://docs.soliditylang.org/en/v0.8.15/types.html#iterable-mappings */
    struct KeyFlag { string key; bool deleted; }
    KeyFlag[] public keys; 
    mapping(string => Beekeper) public beekepers;
    uint public size;

    function saveBeekeper(string calldata id, string calldata fullname, uint256 activityStartDate, string calldata location, string calldata infoCid) public returns (bool replaced){
        uint keyIndex = beekepers[id].keyIndex;
        
        if(keyIndex > 0){
            beekepers[id] = Beekeper(id, fullname, activityStartDate, location, infoCid, keyIndex);
            return true;
        } else {
            keyIndex = keys.length;
            keys.push();
            beekepers[id] = Beekeper(id, fullname, activityStartDate, location, infoCid, keyIndex + 1);
            keys[keyIndex].key = id;
            size++;
            return false;
        }
    }

    function removeBeekeper(string calldata id) public returns (bool success){
        uint keyIndex = beekepers[id].keyIndex;
        if(keyIndex == 0){
            return false;
        }

        delete beekepers[id];
        keys[keyIndex - 1].deleted = true;
        size--;
        return true;
    }
    

} 
