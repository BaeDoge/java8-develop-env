// Windows Script Host JScript helper. Compatible with legacy Windows JScript engines.
(function () {
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    var path = WScript.Arguments.Item(0);
    var stream = fso.OpenTextFile(path, 1, false, -2);
    var raw = stream.ReadAll();
    stream.Close();

    var urlMatch = raw.match(/"download_url"\s*:\s*"([^"]+)"/i);
    var shaMatch = raw.match(/"sha256_hash"\s*:\s*"([0-9a-f]{64})"/i);

    if (!urlMatch || !shaMatch) {
        WScript.StdErr.WriteLine("Could not locate download_url or 64-character sha256_hash in Azul metadata.");
        WScript.Quit(2);
    }

    WScript.Echo(urlMatch[1] + "|" + shaMatch[1]);
})();
