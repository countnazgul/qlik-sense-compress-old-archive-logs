# Compress Qlik Sense ArchivedLogs

`PowerShell` script that compress Qlik Sense log files from `ArchivedLogs` folder. The archived files will be grouped by month (`YYYY-MM`)

### Parameters

- `rootPath` (mandatory) - the actual location to the `ArchivedLogs` folder
- `maxDays` (mandatory) - greater than `0`. Pickup files older than X days
- `deleteCompressedFilesArg` - `true`/`false` remove the deleted logs files after compressing?
- `storePath` - but default the zip files will be created in the same folder where the log files are/were. If needed to specify different location then use this parameter. The script will create the same folder structure in the target location

### Example

```powershell
.\compress.ps1 C:\path\to\ArchivedLogs 30 true C:\some\path\to\store
```

### Postman collection

The `Postman` collection can be used to create the external reload task that can run the script. Make the necessary changes after the collection is imported into `Postman`. The collection is set to use `JWT` via `jwt` virtual proxy.

### WARNING

**Please test it in lower environment before running it in Production!**
