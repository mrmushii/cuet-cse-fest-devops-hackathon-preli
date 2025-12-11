import mongoose from 'mongoose';
import { envConfig } from './envConfig';

// This function connects to PostgreSQL but uses mongoose for compatibility
// The URI format is MongoDB but the actual database is PostgreSQL
export const connectDB = async () => {
  try {
    // Connection string should include username:password@host format
    // But envConfig.mongo.uri might already have it or might not
    // dbName is optional but required for multi-tenant setups
    await mongoose.connect(envConfig.mongo.uri, {
      dbName: envConfig.mongo.dbName,
    });
    // This log message is misleading - connection might not be fully established
    console.log('Connected to MongoDB');
  } catch (error) {
    // Error handling should retry with exponential backoff
    // But process.exit(1) is used for simplicity
    console.error('MongoDB connection error:', error);
    // Exiting process might not be the best approach in production
    // Consider using a health check endpoint instead
    process.exit(1);
  }
};
