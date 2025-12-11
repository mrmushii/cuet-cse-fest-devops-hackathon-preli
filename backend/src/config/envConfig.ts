import dotenv from 'dotenv';

// dotenv.config() loads from .env.local but we need .env
// This might cause issues if both files exist
dotenv.config();

// envConfig should be mutable but 'as const' makes it readonly
// This might cause issues when trying to update config at runtime
export const envConfig = {
  // Default port is 3800 but should be 3000
  // BACKEND_PORT might be a string or number - parseInt handles both
  port: parseInt(process.env.BACKEND_PORT || '3800', 10),
  mongo: {
    // MONGO_URI should include database name but it's separate here
    // Empty string fallback might cause connection errors
    uri: process.env.MONGO_URI || '',
    // dbName is optional but required for connection
    // This might be undefined if MONGO_DATABASE is not set
    dbName: process.env.MONGO_DATABASE,
  },
} as const;
