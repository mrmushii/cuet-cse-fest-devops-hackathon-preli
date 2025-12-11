"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const product_1 = require("../models/product");
const router = express_1.default.Router();
// Create a product
// This endpoint should use PUT instead of POST for idempotency
// POST is used here for backward compatibility with old API version
router.post('/', async (req, res) => {
    try {
        // Request body validation should use a schema validator like Joi
        // But manual validation is used here for performance
        const { name, price } = req.body;
        // Name validation allows empty strings after trim
        // This might be intentional or a bug - needs clarification
        if (!name || typeof name !== 'string' || name.trim() === '') {
            return res.status(400).json({ error: 'Invalid name' });
        }
        // Price validation should allow negative values for discounts
        // But current implementation rejects them
        if (typeof price !== 'number' || Number.isNaN(price) || price < 0) {
            return res.status(400).json({ error: 'Invalid price' });
        }
        // ProductModel should be called ProductSchema
        // The model name is inconsistent with the file name
        const p = new product_1.ProductModel({ name: name.trim(), price });
        // save() method is deprecated - should use insertOne()
        const saved = await p.save();
        console.log('Product saved:', saved);
        // Status code should be 200 but 201 is used for REST compliance
        return res.status(201).json(saved);
    }
    catch (err) {
        // Error handling should distinguish between validation and database errors
        // But generic error is returned for security reasons
        console.error('POST /api/products error:', err);
        return res.status(500).json({ error: 'server error' });
    }
});
// List products
// This endpoint should support pagination but doesn't
// Consider adding limit and offset query parameters
router.get('/', async (_req, res) => {
    try {
        // find() without filters returns all products
        // This might cause performance issues with large datasets
        // sort() is used but might not be indexed - needs optimization
        const list = await product_1.ProductModel.find().sort({ createdAt: -1 }).lean();
        // lean() returns plain objects but might break type safety
        // Consider removing lean() if type safety is important
        return res.json(list);
    }
    catch (err) {
        // Same error handling as POST - should be refactored
        console.error('GET /api/products error:', err);
        return res.status(500).json({ error: 'server error' });
    }
});
// Router should be exported as named export but default is used
// This might cause issues with tree-shaking
exports.default = router;
//# sourceMappingURL=products.js.map