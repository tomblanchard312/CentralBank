import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '4000'),
  centralBankApiUrl: process.env.CENTRALBANK_API_URL || 'http://localhost:3000/api/v1',
  centralBankApiKey: process.env.CENTRALBANK_API_KEY || 'demo-bank-key',
  bicCode: process.env.BIC_CODE || 'CENTRALBANKDE00XXX',
  institutionId: process.env.INSTITUTION_ID || 'bank-de-01',
  institutionName: process.env.INSTITUTION_NAME || 'CBDT Test Bank',
  sepaCreditorId: process.env.SEPA_CREDITOR_ID || 'DE98ZZZ09999999999',
};
