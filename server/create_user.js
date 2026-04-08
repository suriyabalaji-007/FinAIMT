const http = require('http');
const data = JSON.stringify({
  name: "Suriya K",
  email: "suriya@example.com",
  phone: "9876543210",
  password: "password123",
  transactionPin: "123456"
});

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/auth/register',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = http.request(options, (res) => {
  console.log('STATUS: ' + res.statusCode);
  res.setEncoding('utf8');
  res.on('data', (chunk) => {
    console.log('BODY: ' + chunk);
  });
});

req.on('error', (e) => {
  console.error('ERROR: ' + e.message);
});

req.write(data);
req.end();
