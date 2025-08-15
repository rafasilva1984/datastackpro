const express = require('express');
const app = express();
app.get('/healthz', (_, res) => res.send('ok'));
app.get('/readyz',  (_, res) => res.send('ok'));
app.get('/login',   (_, res)=> res.json({ok:true}));
app.get('/checkout',(_, res)=> setTimeout(()=>res.json({ok:true}), Math.random()*200));
app.get('/error',   (_, res)=> res.status(500).json({error:'boom'}));
app.listen(process.env.PORT || 3000, ()=> console.log('sampleapp up'));
