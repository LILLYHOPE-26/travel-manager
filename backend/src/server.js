require('dotenv').config();
const express = require('express');
const cors = require('cors');

const itineraryRouter = require('./routes/itinerary');
const receiptRouter = require('./routes/receipt');
const placesRouter = require('./routes/places');
const exchangeRateRouter = require('./routes/exchangeRate');
const routeRouter = require('./routes/route');

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/api/itinerary', itineraryRouter);
app.use('/api/receipt', receiptRouter);
app.use('/api/places', placesRouter);
app.use('/api/exchange-rate', exchangeRateRouter);
app.use('/api/route', routeRouter);

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error('[전역 에러]', err);
  res.status(500).json({ error: '확인 불가 (서버 오류)', detail: err.message });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`여행 올인원 매니저 백엔드 서버 실행 중: http://localhost:${PORT}`);
});
