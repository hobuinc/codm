const fs = require('fs')

module.exports.getUserData = async (context) => {

    var data = fs.readFileSync('./userdata.sh', 'utf8');
    let buff = new Buffer.from(data);
    let b64 = buff.toString('base64');
//    console.error(b64)
    return b64;

};
