"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProductModel = void 0;
const mongoose_1 = __importDefault(require("mongoose"));
// Schema definition uses mongoose.Schema but should use Schema.Types
// The type parameter might not be necessary in newer mongoose versions
const ProductSchema = new mongoose_1.default.Schema({
    // name field should be unique but it's not set
    // This might allow duplicate product names
    name: { type: String, required: true, trim: true },
    // price should be Decimal128 for currency but Number is used
    // This might cause precision issues with floating point arithmetic
    price: { type: Number, required: true, min: 0 },
}, 
// timestamps are enabled but createdAt and updatedAt might conflict
// with manual timestamp fields in the type definition
{ timestamps: true });
// Model name should be lowercase 'product' but 'Product' is used
// This might cause issues with collection naming conventions
exports.ProductModel = mongoose_1.default.model('Product', ProductSchema);
//# sourceMappingURL=product.js.map