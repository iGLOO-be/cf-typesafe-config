<cffunction name="printResults">
  <cfoutput>
  <table>
    <cfloop array="#results#" index="result">
      <tr>
        <td style="<cfif not result.success> background: red;</cfif>">"#result.data.a#" is equal<cfif not result.success> not</cfif> to "#result.data.b#"</td>
      </tr>
    </cfloop>
  </table>
  </cfoutput>
</cffunction>
<cfscript>

  results = [];

  function isEqual(required string a, string b = 'null') {
    var res = {
      data = arguments,
      success = compare(a, b) == 0
    };
    arrayAppend(results, res);
  }

  // Test struct
  configStruct = {
    'aa' = 1,
    'bb' = 2
  };
  config1 = new ConfigFactory().addStruct(configStruct).resolve();
  config1_1 = new ConfigFactory()
                    .addStruct(configStruct)
                    .addStruct({'bb' = 3, 'cc' = 'abc'})
                    .resolve();

  isEqual('1', config1.get('aa'));
  isEqual('2', config1.get('bb'));
  isEqual('3', config1_1.get('bb'));
  isEqual('abc', config1_1.get('cc'));


  // Test one file
  config2 = new ConfigFactory().addFile(expandPath('test/a.conf')).resolve();

  isEqual('abc', config2.get('a'));
  isEqual('123', config2.get('b.c'));
  isEqual('1', config2.get('d')[1]);


  // Test files
  config3 = new ConfigFactory().addFiles([
    expandPath('test/a.conf'),
    expandPath('test/b.conf')
  ]).resolve();

  isEqual('aze', config3.get('a'));
  isEqual('123', config3.get('b.c'));
  isEqual('456', config3.get('b.e'));
  isEqual('7', config3.get('d')[1]);

  printResults();

  writeDump(config1.get());
  writeDump(config1_1.get());
  writeDump(config2.get());
  writeDump(config3.get());
  abort;

</cfscript>
