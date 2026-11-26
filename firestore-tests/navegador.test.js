import assert from 'node:assert/strict';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import { abrirApp, caminhoDoNavegador } from './driver.mjs';

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

test('CHROME_BIN inexistente faz o abrirApp falhar logo, citando CHROME_BIN', { timeout: 20000 }, async () => {
  const anterior = process.env.CHROME_BIN;
  process.env.CHROME_BIN = join(tmpdir(), 'achei-sem-navegador', 'chrome-que-nao-existe');
  const inicio = Date.now();
  try {
    await assert.rejects(abrirApp(), (erro) => {
      assert.match(erro.message, /CHROME_BIN/);
      return true;
    });
    assert.ok(Date.now() - inicio < 5000, `levou ${Date.now() - inicio} ms para falhar`);
  } finally {
    if (anterior === undefined) delete process.env.CHROME_BIN;
    else process.env.CHROME_BIN = anterior;
  }
});
