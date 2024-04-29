let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.21-20220215/package-set.dhall
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  additions =
      [  { name = "cap"
  , repo = "https://github.com/stephenandrews/cap-motoko-library"
  , version = "v1.0.4-alt"
  , dependencies = [] : List Text
  },
      
  { name = "encoding"
  , repo = "https://github.com/aviate-labs/encoding.mo"
  , version = "v0.3.1"
  , dependencies = [ "array", "base" ]
  },
  { name = "array"
  , repo = "https://github.com/aviate-labs/array.mo"
  , version = "v0.1.1"
  , dependencies = [ "base" ]
  },
  { name = "io"
  , repo = "https://github.com/aviate-labs/io.mo"
  , version = "v0.3.0"
  , dependencies = [ "base" ]
  },
  { name = "rand"
  , repo = "https://github.com/aviate-labs/rand.mo"
  , version = "v0.2.1"
  , dependencies = [ "base" ]
  },
  { name = "json"
  , repo = "https://github.com/aviate-labs/json.mo"
  , version = "v0.1.2"
  , dependencies = [ "base", "parser-combinators"]
  },
  { name = "parser-combinators"
  , repo = "https://github.com/aviate-labs/parser-combinators.mo"
  , version = "v0.1.1"
  , dependencies = [ "base" ]
  },
  { name = "uuid"
  , version = "88871a6e1801c61ba54d42966f08be0604bb2a2d"
  , repo = "https://github.com/aviate-labs/uuid.mo"
  , dependencies = [ "base", "encoding", "io" ]
  },] : List Package

in  upstream # additions
