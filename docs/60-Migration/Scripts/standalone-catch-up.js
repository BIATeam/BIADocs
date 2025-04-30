const fs = require('fs');
const path = require('path');
const glob = require('glob');

class ComponentMapping {
  constructor(importName, importFrom, tag, className, attribute) {
    this.importName = importName;
    this.importFrom = importFrom;
    this.tag = tag;
    this.className = className;
    this.attribute = attribute;
  }
}

// Component mapping
const standaloneComponentsMapping = [
  new ComponentMapping(
    'FloatLabel',
    'primeng/floatlabel',
    'p-floatlabel'
  ),
  new ComponentMapping(
    'Button',
    'primeng/button',
    'p-button'
  ),
  new ComponentMapping(
    'Fluid',
    'primeng/fluid',
    'p-fluid'
  ),
  new ComponentMapping(
    'PrimeTemplate',
    'primeng/api',
    '',
    '',
    'pTemplate'
  )
];

class ComponentData {
  constructor(componentPath) {
    this.path = componentPath;
    this.fileName = path.basename(componentPath);
  }
}

// Find all component .ts files
const componentsData = glob
  .sync('src/app/**/*.component.ts')
  .map(componentPath => new ComponentData(componentPath));

// Map component files to their corresponding HTML templates
const componentTemplateMap = new Map();

// Scan .ts files to find external templates (`templateUrl`)
componentsData.forEach(componentData => {
  const content = fs.readFileSync(componentData.path, 'utf8');
  const match = content.match(/templateUrl:\s*['"]([^'"]+)['"]/);

  if (match) {
    const urlPath = match[1];
    const templatePath = urlPath.startsWith('/src') ? 
      __dirname + urlPath : 
      path.resolve(path.dirname(componentData.path),urlPath);
    if (fs.existsSync(templatePath)) {
      componentTemplateMap.set(componentData.path, templatePath);
    }
  }
});

// Function to extract standalone components from an HTML template
function extractStandaloneComponents(templateContent) {
  const usedComponents = [];

  // Regex patterns to catch all components usages
  const tagRegex = /<([a-zA-Z0-9-]+)/g;
  const classRegex = /class=["'][^"']*\b(p-[a-zA-Z0-9-]+)\b[^"']*["']/g;
  const attrRegex = /\b(p[A-Z][a-zA-Z0-9]*)\b/g;

  let match;

  // Tag-based components (e.g., `<component>`)
  while ((match = tagRegex.exec(templateContent)) !== null) {
    const tag = match[1];
    const standaloneComponentMapping = standaloneComponentsMapping.find(
      x => x.tag && x.tag === tag
    );
    if (
      standaloneComponentMapping &&
      !usedComponents.find(
        x => x.importName === standaloneComponentMapping.importName
      )
    ) {
      usedComponents.push(standaloneComponentMapping);
    }
  }

  // Class-based components (e.g., `class="p-component"`)
  while ((match = classRegex.exec(templateContent)) !== null) {
    const className = match[1];
    const standaloneComponentMapping = standaloneComponentsMapping.find(
      x => x.className && x.className === className
    );
    if (
      standaloneComponentMapping &&
      !usedComponents.find(
        x => x.importName === standaloneComponentMapping.importName
      )
    ) {
      usedComponents.push(standaloneComponentMapping);
    }
  }

  // Attribute-based components (e.g., `pComponent`)
  while ((match = attrRegex.exec(templateContent)) !== null) {
    const attribute = match[1];
    const standaloneComponentMapping = standaloneComponentsMapping.find(
      x => x.attribute && x.attribute === attribute
    );
    if (
      standaloneComponentMapping &&
      !usedComponents.find(
        x => x.importName === standaloneComponentMapping.importName
      )
    ) {
      usedComponents.push(standaloneComponentMapping);
    }
  }

  return usedComponents;
}

//const debugComponentsData = componentsData.splice(0, 3);

// Process each component
componentsData.forEach(componentData => {
  let componentContent = fs.readFileSync(componentData.path, 'utf8');
  let templateContent = '';

  // Check if component uses an external template
  if (componentTemplateMap.has(componentData.path)) {
    templateContent = fs.readFileSync(
      componentTemplateMap.get(componentData.path),
      'utf8'
    );
  } else {
    // Detect inline template
    const inlineTemplateMatch = componentContent.match(
      /template:\s*`([\s\S]*?)`|template:\s*"([\s\S]*?)"/
    );
    if (inlineTemplateMatch) {
      templateContent = inlineTemplateMatch[1] || inlineTemplateMatch[2] || '';
    }
  }

  if (!templateContent) {
    console.log(`⚠️  ${componentData.fileName} : no template content`);
    return;
  }

  const usedStandaloneComponents = extractStandaloneComponents(templateContent);
  if (usedStandaloneComponents.length === 0) {
    // console.log(`✅ ${componentData.fileName} : already up to date`);
    return;
  }

  const existingImportsMatch = componentContent.match(
    /imports:\s*\[([\s\S]*?)\]/
  );
  let existingImports = existingImportsMatch
    ? existingImportsMatch[1]
        .replace(/\r/g, '')
        .replace(/\n/g, '')
        .replace(/\t/g, '')
        .split(',')
        .map(x => x.trim())
        .filter(x => x !== '')
    : [];

  const newStandaloneComponents = usedStandaloneComponents.filter(
    component => !existingImports.includes(component.importName)
  );

  if (newStandaloneComponents.length === 0) {
    // console.log(`✅ ${componentData.fileName} : already up to date`);
    return;
  }

  // Check if the component is already standalone  
  const isStandalone = componentContent.includes('imports:');
  // Inject standalone flag and imports
  if (isStandalone) {
    // Add missing imports inside the `imports: []` array
    componentContent = componentContent.replace(
      /imports:\s*\[([\s\S]*?)\]/,
      (match, imports) =>
        `imports: [${imports.trim()}${imports.trim() ? ', ' : ''}${newStandaloneComponents.map(x => x.importName).join(', ')}]`
    );
  } else {
    // If not standalone, add the imports
    componentContent = componentContent.replace(
      /@Component\({/,
      `@Component({\n  imports: [${newStandaloneComponents.map(x => x.importName).join(', ')}],`
    );
  }

  // Generate import statements
  const newImportStatements = newStandaloneComponents.map(
    c => `import { ${c.importName} } from '${c.importFrom}';`
  );
  const uniqueImports = newImportStatements.filter(
    importStatement => !componentContent.includes(importStatement)
  );
  if (uniqueImports.length > 0) {
    componentContent = uniqueImports.join('\n') + '\n' + componentContent;
  }

  // Update the component file with new imports
  fs.writeFileSync(componentData.path, componentContent.replace(',,', ','));
  console.log(`🔄 ${componentData.fileName} : updated`);
});

console.log('🚀 Catch up complete!');
