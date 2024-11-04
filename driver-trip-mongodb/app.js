// app.js

// Import required packages
const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const cors = require("cors");
const dotenv = require("dotenv");
const admin = require("firebase-admin");
const path = require("path");

// Initialize environment variables
dotenv.config();

// Initialize Firebase Admin SDK
const serviceAccount = require(path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Initialize Express app
const app = express();

// Middleware setup
app.use(bodyParser.json());
app.use(cors());

// Connect to MongoDB
mongoose
  .connect(process.env.MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    // useFindAndModify: false, // Deprecated in Mongoose 6
  })
  .then(() => console.log("MongoDB connected successfully"))
  .catch((err) => {
    console.error("Error connecting to MongoDB:", err);
    process.exit(1); // Exit process with failure
  });

// Define the User schema and model
const userSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true }, // Firebase UID
  email: { type: String, required: true, unique: true },
  firstName: { type: String, required: true },
  lastName: { type: String, required: true },
  phoneNumber: { type: String },
  address: { type: String },
  role: { type: String, enum: ["user", "driver", "admin"], default: "user" },
  createdAt: { type: Date, default: Date.now },
});

const User = mongoose.model("User", userSchema);

// Define the Trip schema and model (if managing trips separately)
const tripSchema = new mongoose.Schema({
  tripId: { type: String, required: true, unique: true },
  tripData: {
    startLocation: String,
    endLocation: String,
    timeStamp: { type: Date, default: Date.now },
  },
  // Add more trip-specific fields as needed
});

const Trip = mongoose.model("Trip", tripSchema);

// Define the DriverTrip schema and model
const driverTripSchema = new mongoose.Schema({
  driverName: { type: String, required: true },
  driverId: { type: String, required: true, unique: true }, // Firebase UID
  trips: [tripSchema], // Array of trips
  createdAt: { type: Date, default: Date.now },
});

const DriverTrip = mongoose.model("DriverTrip", driverTripSchema);

// Authentication Middleware to verify Firebase ID Tokens
const authenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Unauthorized: No token provided" });
  }

  const idToken = authHeader.split("Bearer ")[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken; // Attach decoded token to request
    next();
  } catch (error) {
    console.error("Error verifying Firebase ID token:", error);
    return res.status(401).json({ error: "Unauthorized: Invalid token" });
  }
};

// Routes

/**
 * @route   POST /api/users
 * @desc    Create a new user
 * @access  Public
 */
app.post("/api/users", async (req, res) => {
  const {
    userId,
    email,
    firstName,
    lastName,
    phoneNumber,
    address,
    role,
  } = req.body;

  if (!userId || !email || !firstName || !lastName) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    // Check if user already exists
    let existingUser = await User.findOne({ userId });
    if (existingUser) {
      return res.status(400).json({ error: "User already exists" });
    }

    // Create new user
    const newUser = new User({
      userId,
      email,
      firstName,
      lastName,
      phoneNumber,
      address,
      role,
    });

    await newUser.save();
    console.log("New user created:", newUser);
    return res.status(201).json({
      message: "User created successfully",
      user: newUser,
    });
  } catch (error) {
    console.error("Error creating user:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
});

/**
 * @route   GET /api/users/:userId
 * @desc    Fetch user information
 * @access  Protected
 */
app.get("/api/users/:userId", authenticate, async (req, res) => {
  const { userId } = req.params;

  // Ensure the requesting user is fetching their own data or is an admin
  if (req.user.uid !== userId && req.user.role !== "admin") {
    return res.status(403).json({ error: "Forbidden: Access denied" });
  }

  try {
    const user = await User.findOne({ userId }).select("-__v -_id");
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    return res.status(200).json({ user });
  } catch (error) {
    console.error("Error fetching user info:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
});

/**
 * @route   PATCH /api/users/:userId
 * @desc    Update user role
 * @access  Protected (Admin only)
 */
app.patch("/api/users/:userId", authenticate, async (req, res) => {
  const { userId } = req.params;
  const { role } = req.body;

  // Only admin can update roles
  if (req.user.role !== "admin") {
    return res.status(403).json({ error: "Forbidden: Admins only" });
  }

  // Validate role
  const validRoles = ["user", "driver", "admin"];
  if (!validRoles.includes(role)) {
    return res.status(400).json({ error: "Invalid role provided" });
  }

  try {
    const updatedUser = await User.findOneAndUpdate(
      { userId },
      { role },
      { new: true }
    ).select("-__v -_id");

    if (!updatedUser) {
      return res.status(404).json({ error: "User not found" });
    }

    return res.status(200).json({
      message: "User role updated successfully",
      user: updatedUser,
    });
  } catch (error) {
    console.error("Error updating user role:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
});

/**
 * @route   POST /api/create-driver
 * @desc    Create a new driver in the DriverTrip collection
 * @access  Protected
 */
app.post("/api/create-driver", authenticate, async (req, res) => {
  const { driverName, driverId } = req.body;

  if (!driverName || !driverId) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    // Ensure the driverId corresponds to an existing user with role 'driver'
    const user = await User.findOne({ userId: driverId, role: "driver" });
    if (!user) {
      return res.status(400).json({
        error:
          "Driver ID does not correspond to a registered user with role 'driver'",
      });
    }

    // Check if driver already exists
    let existingDriver = await DriverTrip.findOne({
      driverId: driverId,
    });

    if (existingDriver) {
      console.log(`Driver with ID ${driverId} already exists.`);
      return res.status(400).json({
        message: "Driver with the same ID already exists.",
      });
    }

    // Create new driver
    const newDriver = new DriverTrip({
      driverName,
      driverId,
      trips: [], // Initially empty trips array
    });

    await newDriver.save();
    console.log("New driver created:", newDriver);

    return res.status(201).json({
      message: "Driver document created successfully.",
      driver: newDriver,
    });
  } catch (error) {
    console.error("Error creating new driver:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
});

/**
 * @route   POST /api/trips
 * @desc    Create a new trip for a driver
 * @access  Protected
 */
app.post("/api/trips", authenticate, async (req, res) => {
  const { tripId, tripData, driverId } = req.body;

  if (!tripId || !tripData || !driverId) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  try {
    // Find the driver
    const driver = await DriverTrip.findOne({ driverId });
    if (!driver) {
      return res.status(404).json({ error: "Driver not found" });
    }

    // Check if tripId already exists
    const existingTrip = await Trip.findOne({ tripId });
    if (existingTrip) {
      return res.status(400).json({ error: "Trip ID already exists" });
    }

    // Create new trip
    const newTrip = new Trip({
      tripId,
      tripData,
    });

    await newTrip.save();

    // Add trip to driver's trips array
    driver.trips.push(newTrip);
    await driver.save();

    console.log("New trip created and added to driver:", newTrip);

    return res.status(201).json({
      message: "Trip created successfully.",
      trip: newTrip,
    });
  } catch (error) {
    console.error("Error creating trip:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
});

/**
 * @route   GET /api/trips/:tripId
 * @desc    Fetch trip information
 * @access  Protected
 */
app.get("/api/trips/:tripId", authenticate, async (req, res) => {
  const { tripId } = req.params;

  try {
    const trip = await Trip.findOne({ tripId }).select("-__v -_id");
    if (!trip) {
      return res.status(404).json({ error: "Trip not found" });
    }

    return res.status(200).json({ trip });
  } catch (error) {
    console.error("Error fetching trip info:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
});

/**
 * @route   PATCH /api/trips/:tripId
 * @desc    Update trip information
 * @access  Protected (Driver or Admin)
 */
app.patch("/api/trips/:tripId", authenticate, async (req, res) => {
  const { tripId } = req.params;
  const { tripData } = req.body;

  if (!tripData) {
    return res.status(400).json({ error: "No trip data provided for update" });
  }

  try {
    const trip = await Trip.findOneAndUpdate(
      { tripId },
      { tripData },
      { new: true }
    ).select("-__v -_id");

    if (!trip) {
      return res.status(404).json({ error: "Trip not found" });
    }

    return res.status(200).json({
      message: "Trip updated successfully",
      trip,
    });
  } catch (error) {
    console.error("Error updating trip:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
});

/**
 * @route   GET /api/drivers/:driverId/trips
 * @desc    Fetch all trips for a specific driver
 * @access  Protected
 */
app.get("/api/drivers/:driverId/trips", authenticate, async (req, res) => {
  const { driverId } = req.params;

  try {
    const driver = await DriverTrip.findOne({ driverId }).populate("trips").select("-__v -_id");
    if (!driver) {
      return res.status(404).json({ error: "Driver not found" });
    }

    return res.status(200).json({ trips: driver.trips });
  } catch (error) {
    console.error("Error fetching driver's trips:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
});

// Catch-all route for undefined endpoints
app.use((req, res) => {
  res.status(404).json({ error: "Endpoint not found" });
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
