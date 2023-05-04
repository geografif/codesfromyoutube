// Global Industrial and Smallholder Oil Palm Plantation Map from BIOPAMA
// Run on Google Earth Engine: https://destyy.com/egvTGR

// Define dataset
var biopama19 = ee.ImageCollection("BIOPAMA/GlobalOilPalm/v1").select('classification').mosaic();
var maskOP = biopama19.neq(3).where(biopama19.eq(0), 0.6);
var biopama19 = biopama19.updateMask(maskOP).clip(hotspot)

// Display
Map.centerObject(hotspot, 9);
Map.setOptions('SATELLITE');
Map.addLayer(biopama19, {min:1,max:3,palette:['ff0000','ff0111']}, 'Oil Palm');

// Export
Export.image.toDrive({
  image: biopama19,
  description: 'op',
  region: hotspot,
  scale: 10
});
