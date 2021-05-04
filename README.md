# ruml

Generate PlantUML diagrams from Ruby code. 

(work in progress)

#### Install

```
gem "ruml", require: false, git: "https://github.com/srizzo/ruml"
```

#### Configure

```
export RUML_APP_GLOB="app/{models,controllers}/**/*"
export RUML_GROUP_BY_GLOB="spec/{integration,unit}/**/*"
export RUML_EXCLUDE_CALL_REGEX="initialize"
# export RUML_EXCLUDE_CALLER_REGEX="..."
# export RUML_EXCLUDE_CALLEE_REGEX="..."
```

#### Generate Sequence Diagrams from running Ruby scripts

```

ruby -r ruml [script]
rspec -r ruml [spec]
```

#### Query/Manipulate diagrams

https://github.com/srizzo/pumltools
                                 
## The world needs you

- [ ] Add clearer instructions
- [ ] Add sensible defaults and eliminate the need for env variables  
- [ ] Improve performance   
- [ ] Add screenshots / screencasts
- [ ] Add unit tests
- [ ] Extract cli tools / Homebrew package
