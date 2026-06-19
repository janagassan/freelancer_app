import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";
import User from "./User.js";
import SubscriptionPlan from "./SubscriptionPlan.js";

const SubscriptionLog = sequelize.define(
  "SubscriptionLog",
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
    old_plan_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
  model: "subscriptionplans",
  key: "id"
},
    },
    new_plan_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
  model: "subscriptionplans",
  key: "id"
},
    },
    action: {
      type: DataTypes.ENUM(
        "created",
        "upgraded",
        "downgraded",
        "renewed",
        "canceled",
        "expired",
        "payment_failed",
      ),
      allowNull: false,
    },
    amount: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: true,
    },
    coupon_code: {
      type: DataTypes.STRING(50),
      allowNull: true,
    },
    metadata: {
      type: DataTypes.JSON,
      allowNull: true,
    },
    ip_address: {
      type: DataTypes.STRING(45),
      allowNull: true,
    },
    user_agent: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
  },
  {
    tableName: "SubscriptionLogs",
    timestamps: true,
  },
);

SubscriptionLog.belongsTo(User, { foreignKey: "user_id", as: "user" });
SubscriptionLog.belongsTo(SubscriptionPlan, {
  foreignKey: "old_plan_id",
  as: "oldPlan",
});
SubscriptionLog.belongsTo(SubscriptionPlan, {
  foreignKey: "new_plan_id",
  as: "newPlan",
});

export default SubscriptionLog;
