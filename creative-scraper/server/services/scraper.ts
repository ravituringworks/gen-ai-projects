import puppeteer from 'puppeteer';
import * as cheerio from 'cheerio';

export interface ScrapingResult {
  title?: string;
  content: string;
  metadata: {
    url: string;
    scrapedAt: Date;
    wordCount: number;
    links: string[];
    images: string[];
    headings: string[];
  };
}

export class WebScraper {
  async scrapeUrl(url: string): Promise<ScrapingResult> {
    try {
      const browser = await puppeteer.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
      });
      
      const page = await browser.newPage();
      
      // Set user agent to avoid blocking
      await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');
      
      // Navigate with timeout
      await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });
      
      // Get page content
      const htmlContent = await page.content();
      await browser.close();
      
      return this.parseContent(htmlContent, url);
    } catch (error) {
      throw new Error(`Failed to scrape URL: ${error.message}`);
    }
  }

  private parseContent(html: string, url: string): ScrapingResult {
    const $ = cheerio.load(html);
    
    // Remove script and style elements
    $('script, style, nav, footer, aside').remove();
    
    // Extract title
    const title = $('title').text().trim() || $('h1').first().text().trim();
    
    // Extract main content
    let content = '';
    const contentSelectors = ['main', 'article', '[role="main"]', '.content', '#content', '.post', '.entry'];
    
    for (const selector of contentSelectors) {
      const element = $(selector);
      if (element.length > 0) {
        content = element.text().trim();
        break;
      }
    }
    
    // Fallback to body content if no specific content area found
    if (!content) {
      content = $('body').text().trim();
    }
    
    // Clean up content
    content = content.replace(/\s+/g, ' ').trim();
    
    // Extract metadata
    const links = $('a[href]').map((_, el) => $(el).attr('href')).get()
      .filter(href => href && href.startsWith('http'))
      .slice(0, 50); // Limit to first 50 links
    
    const images = $('img[src]').map((_, el) => $(el).attr('src')).get()
      .filter(src => src && (src.startsWith('http') || src.startsWith('/')))
      .slice(0, 20); // Limit to first 20 images
    
    const headings = $('h1, h2, h3, h4, h5, h6').map((_, el) => $(el).text().trim()).get()
      .filter(heading => heading.length > 0)
      .slice(0, 30); // Limit to first 30 headings
    
    return {
      title,
      content,
      metadata: {
        url,
        scrapedAt: new Date(),
        wordCount: content.split(/\s+/).length,
        links,
        images,
        headings,
      }
    };
  }

  async scrapeSocialMedia(platform: string, query: string): Promise<ScrapingResult[]> {
    // Note: This is a simplified implementation
    // In a real application, you would use platform-specific APIs or specialized social media scraping tools
    switch (platform.toLowerCase()) {
      case 'twitter':
        return this.scrapeTwitter(query);
      case 'instagram':
        return this.scrapeInstagram(query);
      case 'linkedin':
        return this.scrapeLinkedIn(query);
      default:
        throw new Error(`Unsupported platform: ${platform}`);
    }
  }

  private async scrapeTwitter(query: string): Promise<ScrapingResult[]> {
    // This would typically use Twitter API or specialized scraping
    // For now, returning mock structure
    throw new Error('Twitter scraping requires API access. Please configure Twitter API credentials.');
  }

  private async scrapeInstagram(query: string): Promise<ScrapingResult[]> {
    // This would typically use Instagram API or specialized scraping
    throw new Error('Instagram scraping requires API access. Please configure Instagram API credentials.');
  }

  private async scrapeLinkedIn(query: string): Promise<ScrapingResult[]> {
    // This would typically use LinkedIn API or specialized scraping
    throw new Error('LinkedIn scraping requires API access. Please configure LinkedIn API credentials.');
  }
}

export const webScraper = new WebScraper();
