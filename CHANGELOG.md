## [0.2.4] - 2020.09.27

* StringUtils: 
** new: enumToString(), stringToEnum()

## [0.2.3] - 2020.09.27

* StringUtils:
** new: asInt(), asFloat()
** fix: regExpOption(): check of empty option
** coverage 100%
* Validation
** new isBool(), isInt(), isNat(), isFloat()

## [0.2.2] - 2020.09.26

* added: web implementation of Configuration (configuration_html.dart)

## [0.2.1] - 2020.09.26

* FileSync:
** improved coverage
** fix: ensureDoesNotExists: missing type
** fix: joinPaths(): avoiding double sep ("//")
** tempFile(): complexity reduced
** new: tempDirectory()
* StringUtils:
** removed: chacheGlobalData() + cachePrivateData(): wrong place

## [0.2.0] - 2020.09.26

* BaseConfiguration:
** new: asFloat(): returns a float value from the configuration
** test coverage configuration_test: 100%
* FileSync:
** fix: _logger may be null: _logger.<method> changed to _logger?.<method>

## [0.1.0] - 2020.09.25

* first implementation, no dart analyzing warnings, coverage > 90%
* V0.2.1 BaseConfiguration, fix in FileSync

## [0.0.1] - 2020.09.25

* Creation on GitHub


