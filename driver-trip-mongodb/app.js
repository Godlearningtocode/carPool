const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");

const app = express();
app.use(bodyParser.json());

// Connect to MongoDB (with corrected MongoDB connection string)
mongoose
  .connect(
    "mongodb+srv://shivamcodes01:Sh%21vamno1@carpool.xl3fo.mongodb.net/carpool?retryWrites=true&w=majority&authSource=admin"
  )
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.error("Error connecting to MongoDB:", err));

// Define the schema for Trip
const tripSchema = new mongoose.Schema({
  tripId: { type: String, required: true },
  tripData: {
    startLocation: String,
    endLocation: String,
    timeStamp: { type: Date, default: Date.now },
  },
});

// Define the schema for DriverTrip
const driverTripSchema = new mongoose.Schema({
  driverName: { type: String, required: true },
  driverId: { type: String, required: true },
  trips: [tripSchema], // Array of trips
});

// Create the Mongoose model for DriverTrip
const DriverTrip = mongoose.model("DriverTrip", driverTripSchema);

/**
 * Function to create a new driver in the `DriverTrip` collection.
 * This will be triggered when a new driver user signs up.
 */

app.post("/api/create-driver", async (req, res) => {
  const { driverName, driverId } = req.body;

  try {
    let existingDriver = await DriverTrip.findOne({
      driverName: driverName,
      driverId: driverId,
    });

    if (existingDriver) {
      // Driver with the same details already exists
      console.log(`Driver ${driverName} with ID ${driverId} already exists.`);
      return res.status(400).send({
        message: "Driver with the same name and ID already exists.",
      });
    }

    const newDriver = new DriverTrip({
      driverName,
      driverId,
      trips: [], // Initially empty trips array
    });

    console.log("Driver data before saving:", newDriver);
    await newDriver.save();
    console.log(`New driver ${driverName} added to DriverTrip collection.`);

    // Send success response
    res.status(200).send({
      message: "Driver document created successfully.",
      driver: newDriver,
    });
  } catch (error) {
    console.error("Error creating new driver:", error);
    res
      .status(500)
      .send({ message: "Internal Server Error", error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
