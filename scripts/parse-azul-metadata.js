// Windows Script Host JScript helper. No Node.js or PowerShell required.
(function () {
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    var path = WScript.Arguments.Item(0);
    var stream = fso.OpenTextFile(path, 1, false, -2);
    var raw = stream.ReadAll();
    stream.Close();

    var records = JSON.parse(raw);
    if (!records || !records.length) {
        throw new Error("Azul metadata response contains no packages.");
    }

    var item = records[0];
    if (!item.download_url || !item.sha256_hash) {
        throw new Error("Azul metadata is missing download_url or sha256_hash.");
    }

    WScript.Echo(item.download_url + "|" + item.sha256_hash);
})();
