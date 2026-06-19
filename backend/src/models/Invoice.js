import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";
import User from "./User.js";
import UserSubscription from "./UserSubscription.js";

const Invoice = sequelize.define(
  "Invoice",
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: "Users",
        key: "id",
      },
    },
    subscription_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
  model: "usersubscriptions",
  key: "id",
}
    },
    invoice_number: {
      type: DataTypes.STRING(50),
      unique: true,
      allowNull: false,
    },
    amount: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
    },
    discount: {
      type: DataTypes.DECIMAL(10, 2),
      defaultValue: 0,
    },
    tax: {
      type: DataTypes.DECIMAL(10, 2),
      defaultValue: 0,
    },
    total: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
    },
    currency: {
      type: DataTypes.STRING(3),
      defaultValue: "USD",
    },
    status: {
      type: DataTypes.ENUM("pending", "paid", "failed", "refunded"),
      defaultValue: "pending",
    },
    pdf_url: {
      type: DataTypes.STRING(500),
      allowNull: true,
    },
    paid_at: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    billing_period_start: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    billing_period_end: {
      type: DataTypes.DATE,
      allowNull: false,
    },
  },
  {
    tableName: "Invoices",
    timestamps: true,
  },
);

Invoice.belongsTo(User, { foreignKey: "user_id", as: "user" });
Invoice.belongsTo(UserSubscription, {
  foreignKey: "subscription_id",
  as: "subscription",
});

export default Invoice;
