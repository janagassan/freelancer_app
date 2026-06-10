import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const UserSubscription = sequelize.define(
  "UserSubscription",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    plan_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    stripe_subscription_id: DataTypes.STRING,
    stripe_customer_id: DataTypes.STRING,
    status: {
      type: DataTypes.ENUM(
        "active",
        "trialing",
        "past_due",
        "canceled",
        "incomplete",
        "expired",
      ),
      defaultValue: "active",
    },
    current_period_start: DataTypes.DATE,
    current_period_end: DataTypes.DATE,
    cancel_at_period_end: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    trial_start: DataTypes.DATE,
    trial_end: DataTypes.DATE,
  },
  {
    tableName: "usersubscriptions",
    underscored: false,
    timestamps: true,
    createdAt: "createdAt",
    updatedAt: "updatedAt",
  },
);

export default UserSubscription;
