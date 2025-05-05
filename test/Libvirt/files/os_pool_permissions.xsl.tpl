<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="pool">
    <pool type='dir'>
      <name><xsl:value-of select="name"/></name>
      <target>
        <path><xsl:value-of select="target/path"/></path>
        <permissions>
          <xsl:copy>
            <xsl:element name="mode">
            <xsl:text>0755</xsl:text>
            </xsl:element>
            <xsl:element name="owner">
            <xsl:text>libvirt-qemu</xsl:text>
            </xsl:element>
            <xsl:element name="group">
            <xsl:text>kvm</xsl:text>
            </xsl:element>
          </xsl:copy>
        </permissions>
      </target>
    </pool>
  </xsl:template>
</xsl:stylesheet>