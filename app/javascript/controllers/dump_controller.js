import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  connect() {
    this.getDumpData();
  }

  getDumpData() {
    fetch('https://s3-us-west-2.amazonaws.com/rubygems-dumps/?prefix=production/public_postgresql')
      .then(response => response.text())
      .then(data => {
        const parser = new DOMParser();
        const xml = parser.parseFromString(data, "application/xml");
        const files = this.parseS3Listing(xml);
        this.render(files);
      })
      .catch(error => {
        console.error(error);
      });
  }

  parseS3Listing(xml) {
    const contents = Array.from(xml.getElementsByTagName('Contents'));
    return contents.map(item => {
      return {
        Key: item.getElementsByTagName('Key')[0].textContent,
        LastModified: item.getElementsByTagName('LastModified')[0].textContent,
        Size: item.getElementsByTagName('Size')[0].textContent,
        StorageClass: item.getElementsByTagName('StorageClass')[0].textContent
      };
    });
  }

  render(files) {
    files
      .filter(item => 'STANDARD' === item.StorageClass)
      .sort((a, b) => Date.parse(b.LastModified) - Date.parse(a.LastModified))
      .forEach(item => {
        let text = `${item.LastModified.replace('.000Z', '')} (${this.bytesToSize(item.Size)})`;
        let uri = `https://s3-us-west-2.amazonaws.com/rubygems-dumps/${item.Key}`;
        this.appendItem(text, uri);
      });
  }

  appendItem(text, uri) {
    const clone = this.templateTarget.content.cloneNode(true);
    const a = clone.querySelector('a')
    a.textContent = text;
    a.href = uri;
    this.element.appendChild(clone)
  }

  bytesToSize(bytes) {
    if (bytes === 0) { return '0 Bytes' }
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return (bytes / Math.pow(k, i)).toPrecision(3) + " " + sizes[i];
  }
}
