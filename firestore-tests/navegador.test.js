import assert from 'node:assert/strict';
import { join } from 'node:path';
import test from 'node:test';

import { caminhoDoNavegador } from './driver.mjs';

const windows = { PROGRAMFILES: 'C:/Program Files', 'PROGRAMFILES(X86)': 'C:/Program Files (x86)' };
const edge = join(windows['PROGRAMFILES(X86)'], 'Microsoft/Edge/Application/msedge.exe');

test('CHROME_BIN vence qualquer caminho conhecido', () => {
  assert.equal(caminhoDoNavegador('win32', { ...windows, CHROME_BIN: 'D:/chrome.exe' }, () => false), 'D:/chrome.exe');
});

test('Windows sem Chrome cai no Edge', () => {
  assert.equal(caminhoDoNavegador('win32', windows, (caminho) => caminho === edge), edge);
});

test('sem navegador, o erro diz como apontar um', () => {
  assert.throws(() => caminhoDoNavegador('win32', windows, () => false), /CHROME_BIN/);
});
