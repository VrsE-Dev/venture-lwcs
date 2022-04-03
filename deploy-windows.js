const { exec } = require('shelljs');


async function main () {

    try {
        exec('sfdx force:source:convert -r force-app -d tmp_convert');
        console.log('converted');
        console.log('-----------');

        exec('sfdx force:mdapi:deploy -d tmp_convert --targetusername partCopy -w 10');
        console.log('finished deployment');
        console.log('-----------');

    } catch (e) {
        console.log('error:', e);
    }
};
main();