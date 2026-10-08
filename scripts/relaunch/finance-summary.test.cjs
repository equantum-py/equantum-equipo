const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const Module=require('node:module');
const ts=require('typescript');
const file=path.resolve(__dirname,'../../lib/finance/summary.ts');
const compiled=ts.transpileModule(fs.readFileSync(file,'utf8'),{
  compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}
}).outputText;
const mod=new Module(file,module);mod.filename=file;mod._compile(compiled,file);
const {calculateFinanceSummary:sum}=mod.exports;
const inv=(id,total,status='issued',currency='PYG')=>({id,total_amount:total,status,currency});
const pay=(id,amount,status='confirmed',currency='PYG')=>({invoice_id:id,amount,status,currency});
test('pending and reversed payments do not count as collected',()=>{
  assert.deepEqual(sum([inv('a',100)],[pay('a',20),pay('a',30,'pending'),pay('a',40,'reversed')],'PYG'),
    {billed:100,collected:20,pending:80});
});
test('overpayment on one invoice cannot cancel another balance',()=>{
  assert.deepEqual(sum([inv('a',100),inv('b',100)],[pay('a',150)],'PYG'),
    {billed:200,collected:150,pending:100});
});
test('draft and void invoices are excluded; currencies stay separate',()=>{
  assert.deepEqual(sum([inv('a',100),inv('draft',500,'draft'),inv('void',500,'void'),inv('usd',50,'issued','USD')],
    [pay('a',10),pay('usd',50,'confirmed','USD')],'PYG'),{billed:100,collected:10,pending:90});
});
test('empty dataset yields valid zero totals',()=>{
  assert.deepEqual(sum([],[],'PYG'),{billed:0,collected:0,pending:0});
});
