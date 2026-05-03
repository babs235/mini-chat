process.env.JWT_SECRET = 'test_secret_key_for_jest';

jest.mock('mysql2', () => ({
  createPool: jest.fn(() => ({
    on: jest.fn(),
    promise: jest.fn(() => ({
      execute: jest.fn().mockResolvedValue([[], []]),
      query: jest.fn().mockResolvedValue([[], []]),
    })),
  })),
}));

const request = require('supertest');
const app = require('../server');

describe('Health check', () => {
  it('GET / repond 200', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
  });
});

describe('Validation inscription', () => {
  it('champs vides renvoient 400', async () => {
    const res = await request(app).post('/auth/register').send({});
    expect(res.statusCode).toBe(400);
  });

  it('username trop court (moins de 3 caracteres) renvoie 400', async () => {
    const res = await request(app)
      .post('/auth/register')
      .send({ username: 'ab', password: 'password123' });
    expect(res.statusCode).toBe(400);
  });

  it('username trop long (plus de 20 caracteres) renvoie 400', async () => {
    const res = await request(app)
      .post('/auth/register')
      .send({ username: 'utilisateur_beaucoup_trop_long', password: 'password123' });
    expect(res.statusCode).toBe(400);
  });

  it('mot de passe trop court (moins de 6 caracteres) renvoie 400', async () => {
    const res = await request(app)
      .post('/auth/register')
      .send({ username: 'babikir', password: '123' });
    expect(res.statusCode).toBe(400);
  });

  it('username avec caracteres speciaux interdit renvoie 400', async () => {
    const res = await request(app)
      .post('/auth/register')
      .send({ username: 'test<script>', password: 'password123' });
    expect(res.statusCode).toBe(400);
  });
});

describe('Protection des routes par token', () => {
  it('GET /messages sans token renvoie 403', async () => {
    const res = await request(app).get('/messages');
    expect(res.statusCode).toBe(403);
  });

  it('POST /messages sans token renvoie 403', async () => {
    const res = await request(app).post('/messages').send({ message: 'test' });
    expect(res.statusCode).toBe(403);
  });

  it('GET /messages avec token invalide renvoie 401', async () => {
    const res = await request(app)
      .get('/messages')
      .set('Authorization', 'token_invalide_bidon');
    expect(res.statusCode).toBe(401);
  });
});

describe('Connexion utilisateur inexistant', () => {
  it('POST /auth/login avec utilisateur qui nexiste pas renvoie 401', async () => {
    const res = await request(app)
      .post('/auth/login')
      .send({ username: 'utilisateur_inexistant', password: 'password123' });
    expect(res.statusCode).toBe(401);
  });
});
