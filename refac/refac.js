const TreeSitter = require('tree-sitter');
const TreeSitterBash = require('tree-sitter-bash');

const parser = new TreeSitter();
parser.setLanguage(TreeSitterBash);

const fs = require('fs');

process.chdir('../');

const sourceCode = fs.readFileSync('x11docker', 'utf8');
const tree = parser.parse(sourceCode);

if (!fs.existsSync('lib')) fs.mkdirSync('lib');

let output = '';

for (const node of tree.rootNode.children) {
  //if (node.type != '\n') console.log(`${node.type}: ${node.text.slice(0, 50)} ...\n`); // debug
  const fnMatch = node.text.match(/^(\w+)\(\)\s*\{/);
  console.dir({ type: node.type, text: node.text });
  /*
  if (node.type == '\n') {
    console.dir({ nl_text: node.text });
  }
  */
  if (node.type == 'function_definition') {
    const fnSource = node.text;
    const fnName = fnMatch[1];
    /*
    if (fnName == 'main') {
      output += node.text; // keep
      continue;
    }
    */
    // replace
    const fnFile = `lib/${fnName}.sh`;
    //console.dir({ fnName }); // debug
    fs.writeFileSync(fnFile, fnSource, 'utf8');
    output += `. ${fnFile}`;
  }
  else {
    if (fnMatch != null) {
      console.log(`warning: node looks like function_definition of '${fnMatch[1]}', but was parsed as ${node.type}`)
    }
    output += node.text; // keep
  }
}

fs.writeFileSync('x11docker.2', output, 'utf8');
