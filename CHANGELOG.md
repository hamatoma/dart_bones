## [0.3.1] - 2020.10.11

Note: not compatible: mysql_db (1)
* mysql_db:
** Constructors: parameters changed to named parameters
** _logger renamed to logger: needed for derived classes

* file_sync:
** new: _logger, setLogger()

## [0.2.7] - 2020.09.30

* all imports in lib/* are explicit, not from package:dart_bones
* pubspec.yaml: versions adapted
* file_sync_none.dart if dart:io is not available

## [0.2.6] - 2020.09.30

* pubspec.yaml for the example
* relative addressing of dart_bones.dart

## [0.2.5] - 2020.09.30

* repaired: dartdoc warnings
* example added

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


