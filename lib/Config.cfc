/**
 * @extends DataStore
 */
component {

    public Config function init(required any config) {
        super.init(config, true);
        variables.data = resolve();
        return this;
    }

    public any function get(string key, any def, boolean safeformat = false) {
        var result = super.get(argumentCollection = arguments);

        if( isNull(result) ) {
            return;
        }

        if( isStruct(result) && structKeyExists(result, 'unwrapped') ) {
            return result.unwrapped();
        }

        if( !isNull(key) && isSimpleValue(result) ) {
            var fileMatch = reFindNoSuck('^\<file\:(.+)\>$', trim(result));
            if( arrayLen(fileMatch) ) {
                var file = fileRead(fileMatch[1]);
                __set(key, file);
                return file;
            }
        }

        return result;
    }

    private struct function resolve(struct new_data = {}, struct _data = variables.data) {
        var i_data = "";

        for( i_data in _data ) {
            var val = _data[i_data];
            if( isStruct(val) ) {
                new_data[i_data] = resolve({}, val);
            } else if (isArray(val)) {
                var arr = [];
                for (var i=1; i<= arrayLen(val); i++) {
                    if( isStruct(val[i]) ) {
                        arr.add(resolve({}, val[i]));
                    } else {
                        arr.add(val[i].unwrapped());
                    }
                }
                new_data[i_data] = arr;
            } else {
                new_data[i_data] = val.unwrapped();
            }
        }

        return new_data;
    }

    // --- util

    private array function reFindNoSuck(required string pattern, required string data, numeric startPos = 1) {
        var awesome = [];
        var sucky = reFindNoCase(arguments.pattern, arguments.data, arguments.startPos, true);

        if (!isArray(sucky.len) || arrayLen(sucky.len) <= 0) {
            //handle no match at all
            return awesome;
        }

        for (var i=1; i<= arrayLen(sucky.len); i++){
            //if there's a match with pos 0 & length 0, that means the mime type was not specified
            if (sucky.len[i] gt 0 && sucky.pos[i] gt 0){
                //don't include the group that matches the entire pattern
                var matchBody = mid(arguments.data, sucky.pos[i], sucky.len[i]);
                if (matchBody != arguments.data){
                    arrayAppend(awesome, matchBody);
                }
            }
        }

        return awesome;
    }

}