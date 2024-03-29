## [1.2.2] - 2021.08.16 MySqlDb

* MySqlDb:
  * new: hasColumn(), executeScript(), executeScriptFile()
  * change: MySqlDb._throwOnError renamed to throwOnError

## [1.2.1] - 2021.07.20 MySqlDb

* MySqlDb:
  * exports now deleteRaw()
  * __breaking change__: expecute() returns now int (count of affected rows)
  * __breaking change__: deleteRaw() returns now int (count of affected rows)
  
## [1.1.2] - 2021.07.17 MySqlDb, BaseConfiguration

* MySqlDb: exports now updateRaw()
* BaseConfiguration: new isEmpty and isNotEmpty
* FileSync: ensureDirectory(): catch exception, result type now bool

## [1.1.1] - 2021.04.24 support multiple platforms

* refactored: dart_bones.dart
* stub methods in file_sync_none, process_sync_none, mysql_db_none
  and os_service-none
* relative imports in some unit tests
* logger_html: new implementation (asDiv())

## [1.1.0] - 2021.04.24 isolated instances of ProcessSync...

* ProcessSync and FileSync:
  * Now it is possible to request a non singleton instance of ProcessSync
   and FileSync: meaningful in different isolates
* OsService:
  * singleton instance (and isolated) like in FileSync

* CryptoEngine: separation from dart:io
  * CryptoBaseEngine contains the main part but it does not contain
    dart:io references
  * CrypytoEngine contains dart:io references: the "true random" initialization
    uses Platform components

* dart_bones.dart:
  * conditional exports for process_sync, os_service, crypto_engine, mysqldb

## [1.0.0] - 2021.04.23 null safety

* null safety
* Breaking changes:
  * string_utils:
  * class StringUtils removed: all static functions are now "plain" functions
  * process_sync:
    * class ProcessSync is now a singleton
    * static methods are now "normal" methods
  * file_sync
    * class FileSync is now a singleton
    * static methods are now "normal" methods

## [0.4.13] - 2021.03.22

* base_logger: new: LEVEL_DEBUG
* new: KissRandom: a pseudo random generator based on the KISS algorithm.
* new: CryptoEngine: for encryption/decryption using a pseudo random generator
* new: os_service: (for linux): groupExists(), groupId(), install(), installService()... 
* logger_io:
  ** Fix in logToFile: now with date/time and '\n'
* mysql_db: new in configuration: timeout
* StringUtils: dateToString(): more placeholders

## [0.4.12] - 2021.02.13

* MySqlDb
** new: getTables(), hasTable()

## [0.4.11] - 2021.02.13

* removed null safety versions
## [0.4.10] - 2021.02.13

* mysql_db_test: fix: readOneString() crashes if no record is found
* dependencies updated

## [0.4.9] - 2021.01.06

* file_sync_io: dart analyzer info issues corrected
* mysql_db_test: dart analyzer info issues corrected

## [0.4.8] - 2020.11.27

* MySqlDb
** traceDataLength can be set in the constructor
** traceDataLength can be set in the configuration
** traceSql(): for SELECT statements the trace is
   split by 'WHERE' if not enough space
* StringUtils:
** limitString(): parameters may be null


## [0.4.7] - 2020.11.17

* FileSync
** fix: ensureDirectory(): path may end with slash
** fix: ensureDirectory(): no change of root directory "/"
** new parameter trailingSlash in parentOf()

## [0.4.6] - 2020.10.20

* dependencies to flutter removed

## [0.4.5] - 2020.10.20

* MySqlDb: fix: parameter sql in traceSql may be null

## [0.4.4] - 2020.10.19

* Logger: 
** logLevel: now public, 
** log() now bool to allow chaining
* MySqlDb: logging of SQL parameters and results
** new: traceDataLength and traceSql()

## [0.4.3] - 2020.10.15

* fix: MySqlDb.fromConfiguration(): wrong reference to MySqlDb()

## [0.4.2] - 2020.10.13

* configuration_io:
** new: fetchYamlMapFromFile()
** error if yaml file content is empty
** more elegant implementation of Configuration.fromFile()

## [0.4.1] - 2020.10.12

API break! not compatible: mysql_db (1)

* mysql_db:
** convertNamedParams() is now static and all parameters are named

## [0.3.1] - 2020.10.11

API break! not compatible: mysql_db (1)
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


