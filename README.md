
# CF typesafe Config

## Usage

### Create config

```
config = new ConfigFactory()
    .addFile('path/file0')
    .addFiles([ 'path/file1', 'path/file2' ])
    .resolve();
```

### Use config

All configs
```
config.get()
```

Specific config
```
config.get('key')
config.get('key.key2')
```

## Resources

- https://github.com/typesafehub/config
- https://github.com/markmandel/JavaLoader
