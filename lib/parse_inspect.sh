parse_inspect() {               # parse json of inspect output using python
  # parse for keys in output of docker|podman|nerdctl inspect.
  # Uses python json parser.
  # $1 String containing inspect output
  # $2...$n Key. For second level keys provide e.g. "jsonstring" "Config" "Cmd"
  
  local Parserscript
  
  Parserscript="$Cachefolder/parse_inspect.py"
  Parserscript="#! $Pythonbin
$(cat << EOF
import json,sys

def parse_inspect(*args):
    """ 
    parse output of docker|podman|nerdctl inspect
    args:
     0: ignored
     1: string containing inspect output
     2..n: json keys. For second level keys provide e.g. "Config","Cmd"
    Prints key value as a string.
    Prints empty string if key not found.
    A list is printed as a string with '' around each element.
    """
    
    output=""
    inspect=args[1]
    inspect=inspect.strip()
    if inspect[0] == "[" :
        inspect=inspect[1:-2] # remove enclosing [ ]

    obj=json.loads(inspect)
    
    for arg in args[2:]: # recursively find the desired object. Command.Cmd is found with args "Command" , "Cmd"
        try:
            obj=obj[arg]
        except:
            obj=""
            
    objtype=str(type(obj))
    if "'list'" in objtype:
        for i in obj:
            output=output+"'"+str(i)+"' "
    else:
        output=str(obj)
    
    if output == "None":
        output=""
        
    print(output)

parse_inspect(*sys.argv)
EOF
  )"
  echo "$Parserscript" | $Pythonbin - "$@"
}