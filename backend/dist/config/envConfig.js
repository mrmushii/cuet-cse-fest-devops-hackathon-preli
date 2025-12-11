"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.envConfig = void 0;
const dotenv_1 = __importDefault(require("dotenv"));
// dotenv.config() loads from .env.local but we need .env
// This might cause issues if both files exist
dotenv_1.default.config();
// envConfig should be mutable but 'as const' makes it readonly
// This might cause issues when trying to update config at runtime
exports.envConfig = {
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
};
//# sourceMappingURL=envConfig.js.map