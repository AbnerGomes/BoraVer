// Teste E2E no Chrome real: cadastra um filme, fecha o navegador, reabre com
// o mesmo perfil e confirma que o filme continua lá (IndexedDB).
const puppeteer = require('puppeteer');

const URL = process.env.URL || 'http://host.docker.internal:8081/';
const PROFILE = '/tmp/boraver-profile';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function open() {
  const browser = await puppeteer.launch({
    headless: 'new',
    userDataDir: PROFILE,
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--disable-gpu'],
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 420, height: 900 });
  page.on('console', (m) => {
    const t = m.text();
    if (/BoraVer|rror/.test(t)) console.log('  [console]', t);
  });
  page.on('pageerror', (e) => console.log('  [pageerror]', e.message));
  await page.goto(URL, { waitUntil: 'networkidle0', timeout: 180000 });
  await page.waitForFunction(() => !document.getElementById('boraver-loading'), { timeout: 120000 });
  await sleep(1500);
  // Liga a árvore de acessibilidade do Flutter para poder interagir pelo DOM.
  await page.evaluate(() => {
    const p = document.querySelector('flt-semantics-placeholder');
    if (p) p.click();
  });
  await sleep(1500);
  return { browser, page };
}

async function labels(page) {
  return page.evaluate(() =>
    [...document.querySelectorAll('flt-semantics, input, textarea')]
      .map((e) => (e.getAttribute('aria-label') || e.textContent || '').trim())
      .filter(Boolean));
}

async function clickText(page, text) {
  const ok = await page.evaluate((text) => {
    const nodes = [...document.querySelectorAll('flt-semantics')].filter((e) => {
      const l = (e.getAttribute('aria-label') || e.textContent || '').trim();
      return l.includes(text);
    });
    // O nó mais interno que contém o texto e é clicável.
    const target = nodes.reverse().find((e) => e.getAttribute('role') === 'button' || e.getAttribute('flt-tappable') !== null) || nodes[0];
    if (!target) return false;
    target.click();
    return true;
  }, text);
  if (!ok) throw new Error(`Não achei "${text}". Labels: ${(await labels(page)).join(' | ')}`);
  await sleep(1200);
}

async function typeInto(page, label, value) {
  const handle = await page.evaluateHandle((label) => {
    const fields = [...document.querySelectorAll('input, textarea')];
    return fields.find((f) => (f.getAttribute('aria-label') || '').includes(label)) || null;
  }, label);
  const el = handle.asElement();
  if (!el) throw new Error(`Campo "${label}" não encontrado. Labels: ${(await labels(page)).join(' | ')}`);
  await el.focus();
  await sleep(600);
  await page.keyboard.type(value, { delay: 40 });
  await sleep(500);
}

(async () => {
  const title = 'Filme Teste Persistência';

  console.log('1) Abrindo app pela primeira vez');
  let { browser, page } = await open();
  await page.screenshot({ path: (process.env.OUT || '/out') + '/web-01-inicio.png' });
  await clickText(page, 'Adicionar primeiro filme');
  await typeInto(page, 'Título', title);
  await typeInto(page, 'Ano de lançamento', '2024');
  await clickText(page, 'Salvar');
  await sleep(1500);
  await page.screenshot({ path: (process.env.OUT || '/out') + '/web-02-apos-salvar.png' });
  const after = (await labels(page)).join(' | ');
  console.log('   contém título após salvar:', after.includes(title));
  await browser.close();

  console.log('2) Reabrindo o navegador com o mesmo perfil');
  ({ browser, page } = await open());
  await page.screenshot({ path: (process.env.OUT || '/out') + '/web-03-reaberto.png' });
  const reopened = (await labels(page)).join(' | ');
  const persisted = reopened.includes(title);
  console.log('   filme continua salvo após reabrir:', persisted);
  console.log('   resumo:', reopened.match(/Quero assistir[^|]*/)?.[0]);
  await browser.close();
  process.exit(persisted ? 0 : 1);
})().catch((e) => {
  console.error('FALHOU:', e.message);
  process.exit(2);
});
