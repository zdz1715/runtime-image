const puppeteer = require('puppeteer');

console.log("process.env['PUPPETEER_CACHE_DIR']", process.env['PUPPETEER_CACHE_DIR']);
console.log("process.env['npm_config_puppeteer_cache_dir']", process.env['npm_config_puppeteer_cache_dir']);
console.log("process.env['npm_package_config_puppeteer_cache_dir']", process.env['npm_package_config_puppeteer_cache_dir']);

console.log("puppeteer:", puppeteer);


(async () => {
    const browser = await puppeteer.launch({args: ['--no-sandbox']});


    const page = await browser.newPage();
    await page.goto('https://www.baidu.com/');
    await page.pdf({path: './baidu.pdf'});

    await browser.close();
})();