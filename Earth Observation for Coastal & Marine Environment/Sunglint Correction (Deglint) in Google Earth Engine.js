var point = ee.Geometry.Point([118.2384259, 2.28512]);
Map.centerObject(point, 13);

var S2 = ee.ImageCollection('COPERNICUS/S2')
  .filterBounds(point)
  .filterDate('2016-06-05', '2016-06-08')
  .sort('CLOUDY_PIXEL_PERCENTAGE')
  .first()
  .clip(roi)

//print('ID:', S2_toa.get('system:index'))

//var s2_idbased = ee.Image('COPERNICUS/S2_SR/20200123T021959_20200123T023235_T50MNE');
Map.addLayer(S2, {bands:['B4','B3','B2']})

var S2_sr = S2
            .select(['B2','B3','B4','B8'])
            .rename(['Blue', 'Green', 'Red', 'NIR'])
            .divide(10000);

/*
Map.addLayer(S2_toa, {
  bands: ['B4', 'B3', 'B2'],
  min: 0,
  max: 0.2
}, 'BOA');*/

//Draw
var lfitB = S2_sr.select(['NIR', 'Blue']).reduceRegion({
  reducer: ee.Reducer.linearFit(),
  geometry: glint,
  scale: 10
});

print('OLS estimate:', lfitB)
print('y-intercept:', lfitB.get('offset'))
print('Slope:', lfitB.get('scale'))


//Create deglint function
function deglint(img) {
  // Linear fit based on pair of each visible band & NIR band
  var linearFitB = img.select(['NIR', 'Blue']).reduceRegion({
    reducer: ee.Reducer.linearFit(),
    geometry: glint,
    scale: 10
  });
  
  var linearFitG = img.select(['NIR', 'Green']).reduceRegion({
    reducer: ee.Reducer.linearFit(),
    geometry: glint,
    scale: 10
  });
  
  var linearFitR = img.select(['NIR', 'Red']).reduceRegion({
    reducer: ee.Reducer.linearFit(),
    geometry: glint,
    scale: 10
  });
  
  //Set slope value as raster and define minimum pixel value of NIR band
  var slopeImage = ee.Dictionary({
    'Blue': linearFitB.get('scale'),
    'Green': linearFitG.get('scale'),
    'Red': linearFitR.get('scale')
  }).toImage();
  
  var minNIR = img.select('NIR').reduceRegion(ee.Reducer.min(),roi)
                .toImage()
  
  //deglint
  return img.select(['Blue', 'Green', 'Red'])
      .subtract(slopeImage.multiply((img.select('NIR').subtract(minNIR))))
  
}


var S2_deglint = deglint(S2_sr)


var histogram2 = ui.Chart.image.histogram({
  image: S2_deglint.select(['Blue', 'Green', 'Red']),
  region: roi,
  scale: 10,
}).setOptions({
  title: 'B2_deglint',
  series: {0: {color:'blue'},
           1: {color:'green'},
           2: {color:'red'},
  }
});

var histogram = ui.Chart.image.histogram({
  image: S2_sr.select(['Blue', 'Green', 'Red']),
  region: roi,
  scale: 10,
}).setOptions({
  title: 'B2_deglint',
  series: {0: {color:'blue'},
           1: {color:'green'},
           2: {color:'red'},
  }
});

var maskland = S2_deglint.gt(0.017);

var S2_deglint_masked = S2_deglint.updateMask(maskland);

var histogram3 = ui.Chart.image.histogram({
  image: S2_deglint_masked.select(['Blue', 'Green', 'Red']),
  region: roi,
  scale: 10,
}).setOptions({
  title: 'B2_deglint_masked',
  series: {0: {color:'blue'},
           1: {color:'green'},
           2: {color:'red'},
  }
});


print(histogram)
print(histogram2)
print(histogram3)

Map.addLayer(S2_sr, {
  bands: ['Red', 'Green', 'Blue'],
  min: 0.0,
  max: 0.15
}, 'Top-of-Atmosphere Reflectance');

Map.addLayer(S2_deglint, {
  bands: ['Red', 'Green', 'Blue'],
  min: 0.0,
  max: 0.15
}, 'Top-of-Atmosphere Reflectance');

Map.addLayer(S2_deglint_masked, {
  bands: ['Red', 'Green', 'Blue'],
  min: 0.0,
  max: 0.15
}, 'Top-of-Atmosphere Reflectance');
