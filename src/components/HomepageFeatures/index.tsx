import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  Svg: React.ComponentType<React.ComponentProps<'svg'>>;
  description: JSX.Element;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Fast development',
    Svg: require('@site/static/img/Tree.svg').default,
    description: (
      <>
        With BIA framework you develop quickly powerful and efficient applications.
      </>
    ),
  },
  {
    title: 'Secured application',
    Svg: require('@site/static/img/Idea.svg').default,
    description: (
      <>
        The application develop with the BIA framework are respect the highest level of security.
        An automatic migration process maintain them easily at the last version.
      </>
    ),
  },
  {
    title: 'Powered by Angular and .Net',
    Svg: require('@site/static/img/Logo.svg').default,
    description: (
      <>
        BIA framework use Angular and .Net. But it is open to other technologies...
      </>
    ),
  },
];

function Feature({title, Svg, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): JSX.Element {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
