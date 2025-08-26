import { app, BrowserWindow } from 'electron';
import * as path from 'path';
if (require('electron-squirrel-startup')) {
    app.quit();
}
var createWindow = function () {
    var mainWindow = new BrowserWindow({
        height: 600,
        width: 800,
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'),
        },
    });
    if (MAIN_WINDOW_VITE_DEV_SERVER_URL) {
        mainWindow.loadURL(MAIN_WINDOW_VITE_DEV_SERVER_URL);
    }
    else {
        mainWindow.loadFile(path.join(__dirname, "../renderer/".concat(MAIN_WINDOW_VITE_NAME, "/index.html")));
    }
    mainWindow.webContents.openDevTools();
};
app.on('ready', createWindow);
app.on('window-all-closed', function () {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});
app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) {
        createWindow();
    }
});
