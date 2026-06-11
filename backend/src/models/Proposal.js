// models/Proposal.js
import { DataTypes } from "sequelize";
import { sequelize } from "../config/db.js";

const Proposal = sequelize.define("Proposal", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  UserId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  ProjectId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  price: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  delivery_time: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  proposal_text: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  status: {
    type: DataTypes.ENUM(
      "pending",
      "accepted",
      "rejected",
      "negotiating",
      "interviewing",
      "contracted",
    ),
    defaultValue: "pending",
  },
  milestones: {
    type: DataTypes.TEXT,
    defaultValue: "[]",
    get() {
      const rawValue = this.getDataValue("milestones");
      return rawValue ? JSON.parse(rawValue) : [];
    },
    set(value) {
      this.setDataValue("milestones", JSON.stringify(value));
    },
  },
  negotiated_data: {
    type: DataTypes.TEXT,
    defaultValue: "{}",
    get() {
      const rawValue = this.getDataValue("negotiated_data");
      return rawValue ? JSON.parse(rawValue) : {};
    },
    set(value) {
      this.setDataValue("negotiated_data", JSON.stringify(value));
    },
  },
  createdAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  updatedAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
});

export default Proposal;
