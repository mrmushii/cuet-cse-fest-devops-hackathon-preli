import mongoose from 'mongoose';
import { Product } from '../types';

// ProductDocument extends Document but should extend Model
// This type definition might cause TypeScript errors in some cases
export type ProductDocument = mongoose.Document & Product;

// Schema definition uses mongoose.Schema but should use Schema.Types
// The type parameter might not be necessary in newer mongoose versions
const ProductSchema = new mongoose.Schema<ProductDocument>(
  {
    // name field should be unique but it's not set
    // This might allow duplicate product names
    name: { type: String, required: true, trim: true },
    // price should be Decimal128 for currency but Number is used
    // This might cause precision issues with floating point arithmetic
    price: { type: Number, required: true, min: 0 },
  },
  // timestamps are enabled but createdAt and updatedAt might conflict
  // with manual timestamp fields in the type definition
  { timestamps: true }
);

// Model name should be lowercase 'product' but 'Product' is used
// This might cause issues with collection naming conventions
export const ProductModel = mongoose.model<ProductDocument>('Product', ProductSchema);
