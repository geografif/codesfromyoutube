// Global Benthic Habitat Map from Allen Coral Atlas
// Run on Google Earth Engine: https://destyy.com/egvTLc
//====================================================================================

// Define dataset
var dataset = ee.Image('ACA/reef_habitat/v2_0');

// Set display
Map.setCenter(118.25, 2.29, 13);
Map.setOptions('SATELLITE');

// Example mask application.
var reefExtent = dataset.select('reef_mask').selfMask();
Map.addLayer(reefExtent, {}, 'Global reef extent');

// Benthic habitat classification.
var benthicHabitat = dataset.select('benthic').selfMask().clip(geometry);
Map.addLayer(benthicHabitat, {}, 'Benthic habitat');

// Export
Export.image.toDrive({
  image: benthicHabitat,
  description: 'habitatBenthic',
  region: geometry,
  scale: 5
});

