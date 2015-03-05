/**
 * @accessors true
 */
component {

    property javaLoader;

    public ConfigFactory function init() {
        variables.configs = [];
        variables.merges = [];

        variables.javaLoader = new vendor.javaloader.JavaLoader([
            getDirectoryFromPath(getCurrentTemplatePath()) & '/vendor/typesafe-config-1.2.1.jar'
        ]);

        return this;
    }

    public ConfigFactory function clear() {
        variables.configs = [];
        return this;
    }

    public ConfigFactory function setMerges(required array merges) {
        variables.merges = merges;
        return this;
    }

    public ConfigFactory function addFile(required string file) {
        arrayAppend(variables.configs, { type = 'file', value  = file });
        return this;
    }

    public ConfigFactory function addFiles(required array files) {
        for( var i=1; i <= arrayLen(files); i++ ) {
            addFile(files[i]);
        }
        return this;
    }

    public ConfigFactory function addString(required string str) {
        arrayAppend(variables.configs, { type = 'string', value  = str });
        return this;
    }

    public ConfigFactory function addStrings(required array strs) {
        for( var i=1; i <= arrayLen(files); i++ ) {
            addString(strs[i]);
        }
        return this;
    }

    public ConfigFactory function addUrl(required string str) {
        arrayAppend(variables.configs, { type = 'url', value  = str });
        return this;
    }

    public ConfigFactory function addUrls(required array urls) {
        for( var i=1; i <= arrayLen(urls); i++ ) {
            addUrl(urls[i]);
        }
        return this;
    }

    public ConfigFactory function addStruct(required struct data) {
        arrayAppend(variables.configs, { type = 'struct', value  = data });
        return this;
    }

    public lib.Config function resolve() {
        var configFactory = getConfigFactory();
        var configContainers = [];

        for( var i=1; i <= arrayLen(variables.configs); i++ ) {
            var _config = variables.configs[i];

            switch( _config.type ) {
                case "file":
                    arrayAppend(configContainers, configFactory.parseFile(
                        createObject('java', 'java.io.File').init(_config.value)
                    ));
                break;
                case "string":
                    arrayAppend(configContainers, configFactory.parseReader(
                        createObject('java', 'java.io.StringReader').init(_config.value)
                    ));
                break;
                case "url":
                    arrayAppend(configContainers, configFactory.parseURL(
                        createObject('java', 'java.net.URL').init(_config.value)
                    ));
                break;
                case "struct":
                    arrayAppend(configContainers, configFactory.parseMap(_config.value));
                break;
            }
        }

        var finalConfig = "";
        for( var i=arrayLen(configContainers); i >= 1; i-- ) {
            var _config = configContainers[i];

            if( !isObject(finalConfig) ) {
                finalConfig = _config;
            } else {
                finalConfig = finalConfig.withFallback(_config);
            }
        }

        // No config contains found, just result a empty config
        if (!isObject(finalConfig)) {
            return new lib.Config({});
        }

        finalConfig = finalConfig.resolve();

        if( !arrayLen(variables.merges) ) {
            return new lib.Config(finalConfig.root());
        }

        var initialConfig = finalConfig;
        var finalConfig = {};
        for( var i=1; i <= arrayLen(variables.merges); i++ ) {
            var merge = merges[i];
            var node = initialConfig.withOnlyPath(merge).root()[merge];
            if( isStruct(node) ) structMerge(finalConfig, node);
        }

        return new lib.Config(finalConfig);
    }


    private struct function structMerge(required struct struct1, required struct struct2) {
        var structs = [];

        var i_arg = "";
        for( i_arg in arguments ) {
            if( isStruct(arguments[i_arg]) ) arrayAppend(structs, arguments[i_arg]);
        }

        if( !arrayLen(structs) ) return {};

        for( var i_struct=2; i_struct <= arrayLen(structs); i_struct++ )  {
            struct2 = structs[i_struct];

            var keyList = listToArray(structKeyList(struct1) & "," & structKeyList(struct2));

            for( var i=1; i <= arrayLen(keyList); i++ ) {
                var key = keyList[i];
                if( structKeyExists(struct1, key) && structKeyExists(struct2, key)
                 && isStruct(struct1[key]) && isStruct(struct2[key]) ) {
                    struct1[key] = structMerge({}, struct1[key], struct2[key]);
                } else {
                    if( structKeyExists(struct2, key) ) {
                        struct1[key] = struct2[key];
                    }
                }
            }
        }

        return struct1;
    }

    private any function getConfigFactory() {
        if( !structKeyExists(variables, 'configFactory') ) {
            variables.configFactory = javaLoader.create('com.typesafe.config.ConfigFactory');
        }
        return variables.configFactory;
    }

}