import mongoose from 'mongoose';
import { Product } from '../types';
export type ProductDocument = mongoose.Document & Product;
export declare const ProductModel: mongoose.Model<ProductDocument, {}, {}, {}, mongoose.Document<unknown, {}, ProductDocument> & mongoose.Document<any, any, any> & Product & {
    _id: mongoose.Types.ObjectId;
}, any>;
//# sourceMappingURL=product.d.ts.map