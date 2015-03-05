/**
 * @output false
 */
component {

    property name="data";

	public DataStore function init(any data, boolean readonly = false) {
    	variables.data = data;
        variables.readonly = readonly;
		return this;
	}

    /**
     * @hint Return true if the dataStore is ready only
     */
    public boolean function isReadyOnly() {
    	return variables.readonly;
    }

	/**
	 * @hint Append new data to the dataStore and merge it with the current data
	 */
	public DataStore function append(required struct values, boolean overwrite = true) {
    	checkReadOnly('append');
    	return __append(argumentCollection = arguments);
	}

	public DataStore function set(required any key, required any value) {
    	checkReadOnly('set');
    	return __set(argumentCollection = arguments);
	}

	public any function get(string key, any def, boolean safe = false) {
    	var data = getData();

    	if( !structKeyExists(arguments, "key") ) {
        	return data;
        }

		if( structKeyExists(data, key) ) {
            if( safe && isSimpleValue(data[key]) ) {
                return safeFormat(data[key]);
            } else {
           		return data[key];
            }
        }

        var _key = '["' & arrayToList(listToArray(key, '.'), '"]["') & '"]';
        try {
        	var result = evaluate('data#_key#');
            if( safe && isSimpleValue(result) ) {
                return safeFormat(result);
            } else {
           		return result;
            }
        } catch(any e) {}

        if( structKeyExists(arguments, "def") ) {
    		if( !variables.readonly ) {
            	data[arguments.key] = def;
            }
            if( safe && isSimpleValue(data[arguments.key]) ) {
                return safeFormat(def);
            } else {
            	return def;
            }
        }

        return;
	}

	public any function getOrSet(required string key, struct collection, any def="") {
		if (structKeyExists(collection, 1)) {
			return set(key, collection[1]);
		}
		if (structKeyExists(collection, key)) {
			return set(key, collection[key]);
		}

		return get(key, def);
	}

	public struct function extract(array keys, boolean throwIfNotExists = false) {
		var data = getData();
		var result = {};

        if( !structKeyExists(arguments, 'keys') ) {
        	keys = structKeyArray(data);
        }

		for( var i=1; i <= arrayLen(keys); i++ ) {
			if( throwIfNotExists || structKeyExists(data, keys[i]) ) {
				result[keys[i]] = data[keys[i]];
			}
		}

		return result;
	}

	public struct function extractWithout(required array keys) {
		var data = getData();
		var dataKeys = structKeyArray(data);
		var result = {};

		for( var i=1; i <= arrayLen(dataKeys); i++ ) {
			if( !arrayFindNoCase(keys, dataKeys[i]) ) {
				result[dataKeys[i]] = data[dataKeys[i]];
			}
		}

		return result;
	}

	public DataStore function clear(string key) {
    	checkReadOnly('clear');
    	return __clear(argumentCollection = arguments);
	}

	public boolean function delete(required string key) {
    	checkReadOnly('delete');
        return __delete(argumentCollection = arguments);
	}

	public array function deleteKeys(required array keys) {
    	checkReadOnly('deleteKeys');
        return __deleteKeys(argumentCollection = arguments);
	}

	public boolean function isEmpty() {
		return structIsEmpty(getData());
	}

	public boolean function has(required any keys) {
		var data = getData();
		var result = true;
        var _arg = "";

        for( _arg in arguments ) {
        	if( !structKeyExists(arguments, _arg) ) {
        		continue;
        	}
        	var arg = arguments[_arg];
        	if( isSimpleValue(arg) ) {
            	result = result && structKeyExists(data, arg);
            } else {
                for( var i = 1; i <= arrayLen(arg); i++ ) {
                    result = result && structKeyExists(data, arg[i]);
                }
            }
        }

		return result;
	}

	public array function keepOnlyKeys(required array keys) {
    	checkReadOnly('keepOnlyKeys');
        return __keepOnlyKeys(argumentCollection = arguments);
	}

	public any function onMissingMethod(required string missingMethodName, required struct missingMethodArguments) {
		if( len(missingMethodName) >= 3 && listFind("set,get", left(missingMethodName, 3)) ) {

			var method = left(missingMethodName, 3);
			var property = replace(missingMethodName, method, "");

			var data = getData();

			var argumentsStr = "property";

			if( structKeyExists(missingMethodArguments, 1) )
				argumentsStr = argumentsStr & ",missingMethodArguments[1]";

			else if( structKeyExists(missingMethodArguments, property) )
				argumentsStr = argumentsStr & ",missingMethodArguments[property]";

			return evaluate("#method#(#argumentsStr#)");

		}

		throw(
			detail="The method #missingMethodName# was not found in component #GetMetaData(this).name#"
		);
	}

	// --- privates

    private struct function getData() {
    	return variables.data;
    }

	private void function checkReadOnly(required string methodName) {
		if( variables.readonly ) {
			throwReadOnly(methodName);
		}
	}

    private void function throwReadOnly(required string methodName) {
    	throw(
        	detail = "DataStore is read only. The method '#methodName#' is not allowed."
        );
    }

    private string function safeFormat(required string str) {
    	return xmlFormat(str);
    }

    // --- write methods

	private DataStore function __set(required any key, required any value) {
		var data = getData();

		// key could be a struct to set the entire scope's value
		if( isStruct(key) ) {
			data = duplicate(key);
		} else {
			data[key] = value;
		}

        return this;
	}

	private DataStore function __append(required struct values, boolean overwrite = true) {
    	structAppend(getData(), values, overwrite);
		return this;
	}

	private DataStore function __clear(string key) {
    	var data = getData();

		if( structKeyExists(arguments, "key") ) {
			clearScope();
		} else if( structKeyExists(data, key) ) {
			structDelete(data, key);
        }

		return this;
	}

	private boolean function __delete(required string key) {
    	var data = getData();

		if( !structKeyExists(data, key) ) {
			return false;
		}

		structDelete(data, key);

		return true;
	}

	private array function __deleteKeys(required array keys) {
    	var keyDeleted = [];

		for( var i=1; i <= arrayLen(keys); i++ ) {
			if( delete(keys[i]) ) {
				arrayAppend(keyDeleted, keys[i]);
			}
		}

		return keyDeleted;
	}

	private array function __keepOnlyKeys(required array keys) {
		var data = getData();
		var datakeys = structKeyArray(data);
		var keysToDelete = [];

		for( var i=1; i <= arrayLen(datakeys); i++ ) {
			if( !arrayFindNoCase(keys, datakeys[i]) ) {
				arrayAppend(keysToDelete, datakeys[i]);
			}
		}

		deleteKeys(keysToDelete);

		return keysToDelete;
	}

}