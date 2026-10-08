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

const commercial=mod.exports.calculateCommercialFinanceSummary;
const sale=(id,amount,currency='PYG')=>({id,gross_amount:amount,currency});
const linked=(id,sale_id,amount,status='issued',currency='PYG')=>({...inv(id,amount,status,currency),sale_id});
test('DOC12 FIN001 separates sold billed and collected',()=>{
  assert.deepEqual(commercial([sale('s',20000000)],[linked('i','s',10000000)],
    [pay('i',5000000)],'PYG'),
    {sold:20000000,billed:10000000,collected:5000000,pendingBilling:10000000,pending:5000000});
});
test('DOC12 FIN008 Golden PYG and FIN003 currency separation',()=>{
  const sales=[sale('p',14000000),sale('u',500,'USD')];
  const invoices=[linked('pi','p',10000000),linked('ui','u',300,'issued','USD')];
  const payments=[pay('pi',7000000),pay('ui',100,'confirmed','USD')];
  assert.deepEqual(commercial(sales,invoices,payments,'PYG'),
    {sold:14000000,billed:10000000,collected:7000000,pendingBilling:4000000,pending:3000000});
  assert.deepEqual(commercial(sales,invoices,payments,'USD'),
    {sold:500,billed:300,collected:100,pendingBilling:200,pending:200});
});
test('billing excess on one sale cannot hide another unbilled sale',()=>{
  assert.deepEqual(commercial([sale('a',100),sale('b',100)],
    [linked('i','a',150)],[],'PYG'),
    {sold:200,billed:150,collected:0,pendingBilling:100,pending:150});
});
test('draft void and other currency invoices do not reduce pending billing',()=>{
  assert.equal(commercial([sale('a',100)],
    [linked('d','a',100,'draft'),linked('v','a',100,'void'),
     linked('u','a',100,'issued','USD')],[],'PYG').pendingBilling,100);
});
test('commercial empty dataset has five zero totals',()=>{
  assert.deepEqual(commercial([],[],[],'PYG'),
    {sold:0,billed:0,collected:0,pendingBilling:0,pending:0});
});
