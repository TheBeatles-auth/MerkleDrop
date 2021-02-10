const program = require('commander'); 
const  fs = require('fs');
import { parseBalanceMap } from '../src/parse-balance-map'
const data = "scripts/Address.json";
program
  .version('0.0.0')
 
program.parse(process.argv)

const json = JSON.parse(fs.readFileSync(data, { encoding: 'utf8' }))

if (typeof json !== 'object') throw new Error('Invalid JSON')

console.log(JSON.stringify(parseBalanceMap(json)))
